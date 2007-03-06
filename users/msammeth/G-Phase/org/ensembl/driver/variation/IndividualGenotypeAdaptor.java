/*
	Copyright (C) 2003 EBI, GRL

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

package org.ensembl.driver.variation;

import java.util.List;

import org.ensembl.datamodel.variation.Individual;
import org.ensembl.datamodel.variation.IndividualGenotype;
import org.ensembl.driver.Adaptor;
import org.ensembl.driver.AdaptorException;

/**
 * This adaptor provides database connectivity for IndividualGenotype objects.
 *
 * @author <a href="mailto:craig@ebi.ac.uk">Craig Melsopp</a>
 */
public interface IndividualGenotypeAdaptor extends Adaptor {

	final String TYPE = "individual_genotype";
	
  /**
   * Retrieves an IndividualGenotype via its unique internal identifier.
   * @return IndividualGenotype with matching internalID or null if none found.
   */
   IndividualGenotype fetch(long internalID) throws AdaptorException;

  /**
   * Retrieves all IndividualGenotypes stored for a particual Individual.
   * @return zero or more IndividualGenotypes stored for a particual Individual.
   */
  List fetch(Individual individual) throws AdaptorException;


}